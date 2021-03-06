using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Frapid.Configuration;
using Frapid.Configuration.Db;
using Frapid.Framework.Extensions;
using Frapid.NPoco;
using MixERP.Finance.DTO;
using MixERP.Finance.ViewModels;

namespace MixERP.Finance.DAL
{
    public static class ExchangeRates
    {
        public static async Task<long> SaveAsync(string tenant, int officeId, string baseCurrency,
            List<ExchangeRateViewModel> exchangeRates)
        {
            long exchangeRateId = 0;

            using (var db = DbProvider.Get(FrapidDbServer.GetConnectionString(tenant), tenant).GetDatabase())
            {
                db.BeginTransaction();

                try
                {
                    var sql = new Sql("UPDATE finance.exchange_rates SET status = @0 WHERE office_id=@1", false, officeId);
                    await db.ExecuteAsync(sql);

                    var exchangeRate = new ExchangeRate
                    {
                        OfficeId = officeId,
                        Status = true,
                        UpdatedOn = DateTimeOffset.UtcNow
                    };

                    var awaiter =
                        await db.InsertAsync("finance.exchange_rates", "exchange_rate_id", true, exchangeRate).ConfigureAwait(false);

                    exchangeRateId = awaiter.To<long>();

                    foreach (var item in exchangeRates)
                    {
                        var detail = new ExchangeRateDetail
                        {
                            ExchangeRateId =  exchangeRateId,
                            LocalCurrencyCode = baseCurrency,
                            ForeignCurrencyCode = item.CurrencyCode,
                            ExchangeRate = item.Rate,
                            Unit = 1                            
                        };

                        await db.InsertAsync("finance.exchange_rate_details", "exchange_rate_detail_id", true, detail);
                    }

                    db.CompleteTransaction();
                }
                catch (Exception)
                {
                    db.AbortTransaction();
                }

                return exchangeRateId;
            }
        }
    }
}